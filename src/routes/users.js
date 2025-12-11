const express = require('express');

const router = express.Router();

const sampleUsers = [
  {
    id: '1',
    name: 'Satish Kumar',
    email: 'satish@gmail.com',
    createdAt: '2024-01-01T00:00:00.000Z'
  },
  {
    id: '2',
    name: 'Venkat',
    email: 'venkat@gmail.com',
    createdAt: '2024-01-02T00:00:00.000Z'
  },
  {
    id: '3',
    name: 'Charlie Brown',
    email: 'charlie@example.com',
    createdAt: '2024-01-03T00:00:00.000Z'
  }
];

router.get('/', (req, res) => {
  res.json({
    users: sampleUsers,
    count: sampleUsers.length
  });
});

module.exports = router;
