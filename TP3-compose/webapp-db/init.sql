CREATE TABLE IF NOT EXISTS visits (
    id SERIAL PRIMARY KEY,
    ip_address VARCHAR(45) NOT NULL,
    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO messages (name, message) VALUES
    ('Systeme', 'Bienvenue sur Podman Workshop'),
    ('Admin', 'Base de donnees initialisee');
