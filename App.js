import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [newUser, setNewUser] = useState({ name: '', email: '' });
  const [apiInfo, setApiInfo] = useState(null);

  const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';

  useEffect(() => {
    fetchUsers();
    fetchApiInfo();
  }, []);

  const fetchUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.get(`${API_BASE_URL}/api/v1/users`);
      setUsers(response.data.data);
    } catch (err) {
      setError('Failed to fetch users: ' + err.message);
      console.error('Error fetching users:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchApiInfo = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/v1/info`);
      setApiInfo(response.data);
    } catch (err) {
      console.error('Error fetching API info:', err);
    }
  };

  const handleAddUser = async (e) => {
    e.preventDefault();
    if (!newUser.name || !newUser.email) {
      setError('Name and email are required');
      return;
    }

    try {
      const response = await axios.post(`${API_BASE_URL}/api/v1/users`, newUser);
      setUsers([...users, response.data]);
      setNewUser({ name: '', email: '' });
      setError(null);
    } catch (err) {
      setError('Failed to add user: ' + err.message);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>GitOps Kubernetes on GCP</h1>
        <p>Full-Stack Application with Terraform, Ansible & Argo CD</p>
      </header>

      {apiInfo && (
        <div className="api-info">
          <h2>API Status</h2>
          <p><strong>Service:</strong> {apiInfo.service}</p>
          <p><strong>Version:</strong> {apiInfo.version}</p>
          <p><strong>Environment:</strong> {apiInfo.environment}</p>
          <p><strong>Uptime:</strong> {apiInfo.uptime.toFixed(2)}s</p>
        </div>
      )}

      <div className="container">
        <section className="users-section">
          <h2>Users Management</h2>

          <form onSubmit={handleAddUser} className="add-user-form">
            <h3>Add New User</h3>
            <input
              type="text"
              placeholder="Name"
              value={newUser.name}
              onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
              required
            />
            <input
              type="email"
              placeholder="Email"
              value={newUser.email}
              onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
              required
            />
            <button type="submit">Add User</button>
          </form>

          {error && <div className="error">{error}</div>}

          {loading ? (
            <p className="loading">Loading users...</p>
          ) : (
            <div className="users-list">
              <h3>Users ({users.length})</h3>
              {users.length === 0 ? (
                <p>No users found</p>
              ) : (
                <table>
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Name</th>
                      <th>Email</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map((user) => (
                      <tr key={user.id}>
                        <td>{user.id}</td>
                        <td>{user.name}</td>
                        <td>{user.email}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          )}
        </section>

        <section className="tech-stack">
          <h2>Tech Stack</h2>
          <div className="tech-grid">
            <div className="tech-card">
              <h4>Infrastructure</h4>
              <ul>
                <li>Google Cloud Platform (GCP)</li>
                <li>Google Kubernetes Engine (GKE)</li>
                <li>VPC & Compute Engine</li>
              </ul>
            </div>
            <div className="tech-card">
              <h4>Infrastructure as Code</h4>
              <ul>
                <li>Terraform</li>
                <li>Ansible</li>
              </ul>
            </div>
            <div className="tech-card">
              <h4>Container & Orchestration</h4>
              <ul>
                <li>Docker</li>
                <li>Kubernetes</li>
                <li>Argo CD (GitOps)</li>
              </ul>
            </div>
            <div className="tech-card">
              <h4>Service Mesh & CI/CD</h4>
              <ul>
                <li>Linkerd Service Mesh</li>
                <li>GitHub Actions</li>
                <li>Container Registry</li>
              </ul>
            </div>
          </div>
        </section>
      </div>

      <footer className="App-footer">
        <p>&copy; 2024 GitOps Project. All rights reserved.</p>
      </footer>
    </div>
  );
}

export default App;
