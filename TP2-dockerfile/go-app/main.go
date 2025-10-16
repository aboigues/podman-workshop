package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
)

type InfoResponse struct {
    App      string `json:"app"`
    Version  string `json:"version"`
    Hostname string `json:"hostname"`
}

type HealthResponse struct {
    Status string `json:"status"`
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
    hostname, _ := os.Hostname()
    html := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <title>Go App</title>
    <style>
        body { font-family: Arial; margin: 40px; background: #f0f0f0; }
        .container { background: white; padding: 20px; border-radius: 8px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Podman Workshop - Go App</h1>
        <p>Container: %s</p>
        <p>Multi-Stage Build: Optimise</p>
        <a href="/api/info">API Info</a> | <a href="/api/health">Health</a>
    </div>
</body>
</html>
    `, hostname)
    w.Header().Set("Content-Type", "text/html")
    fmt.Fprint(w, html)
}

func infoHandler(w http.ResponseWriter, r *http.Request) {
    hostname, _ := os.Hostname()
    info := InfoResponse{
        App:      "podman-workshop-tp2-go",
        Version:  "1.0.0",
        Hostname: hostname,
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(info)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    health := HealthResponse{Status: "healthy"}
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(health)
}

func main() {
    http.HandleFunc("/", homeHandler)
    http.HandleFunc("/api/info", infoHandler)
    http.HandleFunc("/api/health", healthHandler)
    
    fmt.Println("Server starting on port 8080...")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
