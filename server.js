require("dotenv").config()
const EXPRESS = require('express');
const MYSQL = require('mysql2');
const APP = EXPRESS();
const PORT = process.env.SQL_PORT;
const CONNECTION = MYSQL.createConnection({
    host: "localhost",
    user: "root",
    password: process.env.SQL_PASSWORD,
    database: "systemHandler"
});

CONNECTION.connect(err => {
    if (err) {
      console.error("Error connecting to MySQL:", err);
      return;
    }
    console.log("Connected to MySQL");
});

APP.use(express.json());

APP.post('/users', (req, res) => {
    const { name } = req.body;
    const query = 'INSERT INTO users (name) VALUES (?)';
    connection.query(query, [name], (err, results) => {
      if (err) {
        return res.status(500).send(err);
      }
      res.status(201).send({ id: results.insertId, name });
    });
});
APP.post('/systems', (req, res) => {
    const { user_id, name, activated } = req.body;
    const query = 'INSERT INTO systems (user_id, name, activated) VALUES (?, ?, ?)';
    connection.query(query, [user_id, name, activated], (err, results) => {
      if (err) {
        return res.status(500).send(err);
      }
      res.status(201).send({ id: results.insertId, user_id, name, activated });
    });
});
app.get('/users/:user_id/systems', (req, res) => {
    const { user_id } = req.params;
    const query = 'SELECT * FROM systems WHERE user_id = ?';
    connection.query(query, [user_id], (err, results) => {
      if (err) {
        return res.status(500).send(err);
      }
      res.send(results);
    });
});
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});