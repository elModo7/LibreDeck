package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type Request struct {
	BotonVisual     string `json:"BotonVisual"`
	FicheroEjecutar string `json:"FicheroEjecutar"`
}

type ServerConfig struct {
	Port              int `json:"port"`
	ResourceSharePort int `json:"resourceSharePort"`
}

func main() {
	cfg := loadServerConfig("./conf/server_config.json")
	tcpPort := getenv("TCP_PORT", strconv.Itoa(cfg.Port))

	// Servicio local
	addr := getenv("TCP_ADDR", "0.0.0.0:"+tcpPort)
	advertisedTCPPort := tcpPortFromAddr(addr, tcpPort)
	resourcePort := getenv("RESOURCE_PORT", strconv.Itoa(cfg.ResourceSharePort))
	discoveryPort := getenv("DISCOVERY_PORT", "37921")
	serverName := getenv("SERVER_NAME", defaultServerName())

	// Carpeta donde están los .ahk (botones)
	buttonsDir := getenv("BUTTONS_DIR", "./buttons")

	// Ruta al autohotkey (puede ser el builtin del proyecto)
	ahkExe := getenv("AHK_EXE", `.\lib\autohotkey.exe`)

	absButtons, err := filepath.Abs(buttonsDir)
	if err != nil {
		log.Fatalf("BUTTONS_DIR inválido: %v", err)
	}
	if err := os.MkdirAll(absButtons, 0755); err != nil {
		log.Fatalf("No se pudo crear BUTTONS_DIR: %v", err)
	}

	ln, err := net.Listen("tcp", addr)
	if err != nil {
		log.Fatalf("No se pudo escuchar en %s: %v", addr, err)
	}
	log.Printf("Servidor TCP escuchando en %s", addr)
	log.Printf("Botones: %s", absButtons)
	log.Printf("AutoHotkey: %s", ahkExe)
	if err := startDiscoveryServer(discoveryPort, serverName, advertisedTCPPort, resourcePort); err != nil {
		log.Printf("Discovery UDP desactivado: %v", err)
	} else {
		log.Printf("Discovery UDP escuchando en 0.0.0.0:%s como %q", discoveryPort, serverName)
	}

	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Printf("accept error: %v", err)
			continue
		}
		go handleConn(conn, absButtons, ahkExe)
	}
}

func startDiscoveryServer(discoveryPort, serverName, tcpPort, resourcePort string) error {
	addr, err := net.ResolveUDPAddr("udp4", ":"+discoveryPort)
	if err != nil {
		return err
	}
	conn, err := net.ListenUDP("udp4", addr)
	if err != nil {
		return err
	}

	go func() {
		buf := make([]byte, 2048)
		for {
			n, remote, err := conn.ReadFromUDP(buf)
			if err != nil {
				log.Printf("discovery read error: %v", err)
				continue
			}
			message := string(buf[:n])
			if !strings.HasPrefix(message, "LIBREDECK_DISCOVER") {
				continue
			}

			response := fmt.Sprintf("LIBREDECK_SERVER|version=1|name=%s|tcp_port=%s|resource_port=%s", serverName, tcpPort, resourcePort)
			if _, err := conn.WriteToUDP([]byte(response), remote); err != nil {
				log.Printf("discovery write error: %v", err)
			}
		}
	}()
	return nil
}

func handleConn(conn net.Conn, buttonsDir, ahkExe string) {
	defer conn.Close()

	// OJO: SetDeadline pone read+write deadline. Para conexiones largas, mejor evitarlo:
	// _ = conn.SetDeadline(time.Now().Add(30 * time.Minute))
	// Usa solo ReadDeadline “deslizante” o ninguno.

	_, _ = conn.Write([]byte("LibreDeck Server\n"))

	r := bufio.NewReaderSize(conn, 64*1024)

	var buf []byte
	tmp := make([]byte, 4096)

	for {
		// Deadline “deslizante” para no colgarte si un cliente desaparece
		_ = conn.SetReadDeadline(time.Now().Add(30 * time.Minute))

		n, err := r.Read(tmp)
		if n > 0 {
			buf = append(buf, tmp[:n]...)

			// Extrae 0..N JSON del buffer
			for {
				frame, rest, ok := popJSONObject(buf)
				if !ok {
					break // aún no hay un JSON completo
				}
				buf = rest

				var req Request
				if err := json.Unmarshal(frame, &req); err != nil {
					continue
				}

				// (Opcional) pequeño delay antes de responder
				time.Sleep(100 * time.Millisecond)

				// Responde SOLO con BotonVisual (como tu server AHK)
				if strings.TrimSpace(req.BotonVisual) != "" {
					_, _ = conn.Write([]byte(req.BotonVisual + "\n"))
				}

				target, err := resolveLocalButton(buttonsDir, req.FicheroEjecutar)
				if err != nil {
					continue
				}

				cmd := exec.Command(ahkExe, target)
				cmd.Dir = filepath.Dir(buttonsDir)
				_ = cmd.Start()
			}
		}

		if err != nil {
			if err == io.EOF {
				return
			}
			// Si fuese timeout, podrías continuar; aquí lo dejamos simple:
			log.Printf("read error: %v", err)
			return
		}
	}
}

func popJSONObject(b []byte) (frame []byte, rest []byte, ok bool) {
	// Saltar espacios
	i := 0
	for i < len(b) && (b[i] == ' ' || b[i] == '\n' || b[i] == '\r' || b[i] == '\t') {
		i++
	}
	if i >= len(b) {
		return nil, b[:0], false
	}

	// Buscar '{'
	for i < len(b) && b[i] != '{' {
		i++
	}
	if i >= len(b) {
		return nil, b, false
	}

	start := i
	depth := 0
	inString := false
	escape := false

	for j := start; j < len(b); j++ {
		c := b[j]

		if inString {
			if escape {
				escape = false
				continue
			}
			if c == '\\' {
				escape = true
				continue
			}
			if c == '"' {
				inString = false
			}
			continue
		}

		switch c {
		case '"':
			inString = true
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				frame = bytes.TrimSpace(b[start : j+1])
				rest = b[j+1:]
				return frame, rest, true
			}
		}
	}

	return nil, b, false
}

// Permite scripts dentro de BUTTONS_DIR. El cliente puede enviar
// "OBS/1.ahk" o la ruta nueva completa "buttons/OBS/1.ahk".
func resolveLocalButton(buttonsDir, fileName string) (string, error) {
	fn := strings.TrimSpace(fileName)
	if fn == "" {
		return "", fmt.Errorf("missing_file")
	}

	fn = filepath.Clean(filepath.FromSlash(fn))
	if filepath.IsAbs(fn) || strings.Contains(fn, "..") || strings.Contains(fn, ":") {
		return "", fmt.Errorf("invalid_file_path")
	}

	parts := strings.Split(fn, string(filepath.Separator))
	if len(parts) > 0 && strings.EqualFold(parts[0], "buttons") {
		fn = filepath.Join(parts[1:]...)
	}

	if strings.ToLower(filepath.Ext(fn)) != ".ahk" {
		return "", fmt.Errorf("only_ahk_supported")
	}

	full := filepath.Join(buttonsDir, fn)
	absButtons, err := filepath.Abs(buttonsDir)
	if err != nil {
		return "", fmt.Errorf("invalid_buttons_dir")
	}
	absFull, err := filepath.Abs(full)
	if err != nil {
		return "", fmt.Errorf("invalid_file_path")
	}
	rel, err := filepath.Rel(absButtons, absFull)
	if err != nil || rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("outside_buttons_dir")
	}

	if _, err := os.Stat(absFull); err != nil {
		return "", fmt.Errorf("file_not_found")
	}
	return absFull, nil
}

func getenv(k, def string) string {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	return v
}

func loadServerConfig(path string) ServerConfig {
	cfg := ServerConfig{Port: 7778, ResourceSharePort: 7779}
	data, err := os.ReadFile(path)
	if err != nil {
		return cfg
	}
	_ = json.Unmarshal(data, &cfg)
	if cfg.Port == 0 {
		cfg.Port = 7778
	}
	if cfg.ResourceSharePort == 0 {
		cfg.ResourceSharePort = 7779
	}
	return cfg
}

func tcpPortFromAddr(addr, fallback string) string {
	_, port, err := net.SplitHostPort(addr)
	if err != nil || port == "" {
		return fallback
	}
	return port
}

func defaultServerName() string {
	name, err := os.Hostname()
	if err != nil || strings.TrimSpace(name) == "" {
		return "LibreDeck Server"
	}
	return name
}
