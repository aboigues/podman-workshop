import React, { useState, useEffect } from 'react';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || '/api';

function App() {
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState({ total: 0, pending: 0, in_progress: 0, completed: 0 });
  const [newTask, setNewTask] = useState({ title: '', description: '' });
  const [health, setHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Fetch health status
  const fetchHealth = async () => {
    try {
      const response = await fetch(`${API_URL}/health`);
      const data = await response.json();
      setHealth(data);
    } catch (err) {
      console.error('Error fetching health:', err);
    }
  };

  // Fetch tasks
  const fetchTasks = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_URL}/tasks`);
      if (!response.ok) throw new Error('Failed to fetch tasks');
      const data = await response.json();
      setTasks(data);
      setError(null);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Fetch stats
  const fetchStats = async () => {
    try {
      const response = await fetch(`${API_URL}/stats`);
      if (!response.ok) throw new Error('Failed to fetch stats');
      const data = await response.json();
      setStats(data);
    } catch (err) {
      console.error('Error fetching stats:', err);
    }
  };

  // Create task
  const createTask = async (e) => {
    e.preventDefault();
    if (!newTask.title.trim()) return;

    try {
      const response = await fetch(`${API_URL}/tasks`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newTask)
      });

      if (!response.ok) throw new Error('Failed to create task');

      setNewTask({ title: '', description: '' });
      fetchTasks();
      fetchStats();
    } catch (err) {
      setError(err.message);
    }
  };

  // Update task status
  const updateTaskStatus = async (id, newStatus) => {
    try {
      const response = await fetch(`${API_URL}/tasks/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
      });

      if (!response.ok) throw new Error('Failed to update task');

      fetchTasks();
      fetchStats();
    } catch (err) {
      setError(err.message);
    }
  };

  // Delete task
  const deleteTask = async (id) => {
    if (!window.confirm('Are you sure you want to delete this task?')) return;

    try {
      const response = await fetch(`${API_URL}/tasks/${id}`, {
        method: 'DELETE'
      });

      if (!response.ok) throw new Error('Failed to delete task');

      fetchTasks();
      fetchStats();
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    fetchHealth();
    fetchTasks();
    fetchStats();

    // Refresh health every 10 seconds
    const healthInterval = setInterval(fetchHealth, 10000);

    return () => clearInterval(healthInterval);
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>TaskPlatform</h1>
        <p>Manage your tasks efficiently</p>
      </header>

      {/* Health Status */}
      {health && (
        <div className={`health-status ${health.status}`}>
          <strong>Status:</strong> {health.status.toUpperCase()}
          {' | '}
          <strong>PostgreSQL:</strong> {health.services.postgres}
          {' | '}
          <strong>Redis:</strong> {health.services.redis}
          {' | '}
          <strong>Uptime:</strong> {Math.floor(health.uptime)}s
        </div>
      )}

      {/* Stats */}
      <div className="stats">
        <div className="stat-card">
          <div className="stat-number">{stats.total}</div>
          <div className="stat-label">Total Tasks</div>
        </div>
        <div className="stat-card pending">
          <div className="stat-number">{stats.pending}</div>
          <div className="stat-label">Pending</div>
        </div>
        <div className="stat-card in-progress">
          <div className="stat-number">{stats.in_progress}</div>
          <div className="stat-label">In Progress</div>
        </div>
        <div className="stat-card completed">
          <div className="stat-number">{stats.completed}</div>
          <div className="stat-label">Completed</div>
        </div>
      </div>

      {/* New Task Form */}
      <div className="new-task-form">
        <h2>Create New Task</h2>
        <form onSubmit={createTask}>
          <input
            type="text"
            placeholder="Task title"
            value={newTask.title}
            onChange={(e) => setNewTask({ ...newTask, title: e.target.value })}
            required
          />
          <textarea
            placeholder="Task description (optional)"
            value={newTask.description}
            onChange={(e) => setNewTask({ ...newTask, description: e.target.value })}
            rows="3"
          />
          <button type="submit">Add Task</button>
        </form>
      </div>

      {/* Error Message */}
      {error && (
        <div className="error-message">
          Error: {error}
        </div>
      )}

      {/* Tasks List */}
      <div className="tasks-container">
        <h2>Tasks</h2>
        {loading ? (
          <p>Loading tasks...</p>
        ) : tasks.length === 0 ? (
          <p className="no-tasks">No tasks yet. Create one above!</p>
        ) : (
          <div className="tasks-list">
            {tasks.map(task => (
              <div key={task.id} className={`task-card ${task.status}`}>
                <div className="task-header">
                  <h3>{task.title}</h3>
                  <span className={`status-badge ${task.status}`}>
                    {task.status.replace('_', ' ')}
                  </span>
                </div>
                {task.description && (
                  <p className="task-description">{task.description}</p>
                )}
                <div className="task-actions">
                  <select
                    value={task.status}
                    onChange={(e) => updateTaskStatus(task.id, e.target.value)}
                    className="status-select"
                  >
                    <option value="pending">Pending</option>
                    <option value="in_progress">In Progress</option>
                    <option value="completed">Completed</option>
                  </select>
                  <button
                    onClick={() => deleteTask(task.id)}
                    className="delete-btn"
                  >
                    Delete
                  </button>
                </div>
                <div className="task-meta">
                  Created: {new Date(task.created_at).toLocaleString()}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
