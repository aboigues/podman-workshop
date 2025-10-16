<?php
$host = getenv('DB_HOST') ?: 'database';
$dbname = getenv('DB_NAME') ?: 'webapp';
$user = getenv('DB_USER') ?: 'webapp_user';
$pass = getenv('DB_PASS') ?: 'webapp_pass';

try {
    $pdo = new PDO("pgsql:host=$host;dbname=$dbname", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("INSERT INTO visits (ip_address) VALUES (?)");
    $stmt->execute([$_SERVER['REMOTE_ADDR'] ?? 'unknown']);
    
    $visits = $pdo->query("SELECT COUNT(*) FROM visits")->fetchColumn();
    $messages = $pdo->query("SELECT * FROM messages ORDER BY created_at DESC")->fetchAll(PDO::FETCH_ASSOC);
    
} catch(PDOException $e) {
    die("<h1>Erreur connexion</h1><p>" . $e->getMessage() . "</p>");
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>WebApp avec PostgreSQL</title>
    <style>
        body {
            font-family: Arial;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            padding: 30px;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        .message {
            background: #e8f5e9;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>WebApp avec PostgreSQL</h1>
        
        <div class="stats">
            <div class="stat-card">
                <h3>Visites</h3>
                <p><?php echo $visits; ?></p>
            </div>
            <div class="stat-card">
                <h3>Database</h3>
                <p>PostgreSQL</p>
            </div>
        </div>
        
        <h2>Messages</h2>
        <?php foreach($messages as $msg): ?>
            <div class="message">
                <strong><?php echo htmlspecialchars($msg['name']); ?></strong>
                <p><?php echo htmlspecialchars($msg['message']); ?></p>
            </div>
        <?php endforeach; ?>
    </div>
</body>
</html>
