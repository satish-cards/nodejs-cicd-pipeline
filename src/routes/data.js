const express = require('express');

const router = express.Router();

const sampleData = [
  {
    id: '1',
    value: 'Sample data item 1',
    timestamp: '2024-01-01T10:00:00.000Z',
    metadata: { type: 'example', priority: 'high' }
  },
  {
    id: '2',
    value: 'Sample data item 2',
    timestamp: '2024-01-01T11:00:00.000Z',
    metadata: { type: 'example', priority: 'medium' }
  },
  {
    id: '3',
    value: 'Sample data item 3',
    timestamp: '2024-01-01T12:00:00.000Z',
    metadata: { type: 'example', priority: 'low' }
  }
];

router.get('/', (req, res) => {
  res.json({
    data: sampleData,
    count: sampleData.length
  });
});

module.exports = router;
