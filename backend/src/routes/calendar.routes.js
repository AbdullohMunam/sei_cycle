const express = require('express');

const {
  createSchedule,
  deleteSchedule,
  getScheduleById,
  getSchedules,
  updateSchedule,
} = require('../controllers/calendar.controller');

const router = express.Router();

router.get('/', getSchedules);
router.post('/', createSchedule);
router.get('/:id', getScheduleById);
router.patch('/:id', updateSchedule);
router.delete('/:id', deleteSchedule);

module.exports = router;
