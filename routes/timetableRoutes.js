const express = require('express');
const router = express.Router();

/*
  SAMPLE STRUCTURE:
  department → year → section → timetable
*/

const timetableData = {
  CSE: {
    "1st Year": {
      A: [
        { day: "Monday", periods: ["Maths", "Physics", "Chemistry", "English"] },
        { day: "Tuesday", periods: ["Biology", "Maths", "Physics", "Lab"] },
        { day: "Wednesday", periods: ["Chemistry", "English", "Maths", "Sports"] },
        { day: "Thursday", periods: ["Physics", "Maths", "Lab", "English"] },
        { day: "Friday", periods: ["Maths", "Chemistry", "Physics", "Library"] }
      ],
      B: [
        { day: "Monday", periods: ["Physics", "Maths", "English", "Chemistry"] },
        { day: "Tuesday", periods: ["Maths", "Biology", "Lab", "Physics"] },
        { day: "Wednesday", periods: ["English", "Maths", "Sports", "Chemistry"] },
        { day: "Thursday", periods: ["Maths", "Physics", "English", "Lab"] },
        { day: "Friday", periods: ["Chemistry", "Maths", "Library", "Physics"] }
      ]
    },

    "2nd Year": {
      A: [
        { day: "Monday", periods: ["DSA", "OOPS", "DBMS", "Maths"] },
        { day: "Tuesday", periods: ["OS", "DSA", "Lab", "DBMS"] },
        { day: "Wednesday", periods: ["OOPS", "Maths", "DSA", "Sports"] },
        { day: "Thursday", periods: ["DBMS", "OS", "Lab", "Maths"] },
        { day: "Friday", periods: ["DSA", "OOPS", "Library", "DBMS"] }
      ]
    },

    "3rd Year": {
      A: [
        { day: "Monday", periods: ["AI", "ML", "CN", "SE"] },
        { day: "Tuesday", periods: ["Cloud", "AI", "Lab", "ML"] },
        { day: "Wednesday", periods: ["CN", "SE", "AI", "Sports"] },
        { day: "Thursday", periods: ["ML", "Cloud", "Lab", "SE"] },
        { day: "Friday", periods: ["AI", "CN", "Library", "ML"] }
      ]
    },

    "4th Year": {
      A: [
        { day: "Monday", periods: ["Project", "Seminar", "AI", "Elective"] },
        { day: "Tuesday", periods: ["Internship", "Project", "Lab", "Elective"] },
        { day: "Wednesday", periods: ["Seminar", "AI", "Project", "Sports"] },
        { day: "Thursday", periods: ["Elective", "Lab", "Project", "AI"] },
        { day: "Friday", periods: ["Project", "Seminar", "Library", "Elective"] }
      ]
    }
  },

  ECE: {
    "1st Year": {
      A: [
        { day: "Monday", periods: ["Maths", "Physics", "Basic Electronics", "English"] },
        { day: "Tuesday", periods: ["Maths", "Lab", "Physics", "Chemistry"] },
        { day: "Wednesday", periods: ["Electronics", "Maths", "English", "Sports"] },
        { day: "Thursday", periods: ["Physics", "Maths", "Lab", "English"] },
        { day: "Friday", periods: ["Maths", "Electronics", "Library", "Physics"] }
      ]
    }
  },

  MECH: {
    "1st Year": {
      A: [
        { day: "Monday", periods: ["Maths", "Physics", "Workshop", "English"] },
        { day: "Tuesday", periods: ["Mechanics", "Maths", "Lab", "Physics"] },
        { day: "Wednesday", periods: ["Workshop", "Maths", "English", "Sports"] },
        { day: "Thursday", periods: ["Physics", "Mechanics", "Lab", "Maths"] },
        { day: "Friday", periods: ["Maths", "Workshop", "Library", "Physics"] }
      ]
    }
  }
};


/*
  GET /api/timetable?department=CSE&year=1st Year&section=A
*/

router.get('/timetable', (req, res) => {
  try {
    const { department, year, section } = req.query;

    // Validation
    if (!department || !year || !section) {
      return res.status(400).json({
        success: false,
        message: "Please provide department, year, and section"
      });
    }

    const deptData = timetableData[department];
    if (!deptData) {
      return res.status(404).json({
        success: false,
        message: "Department not found"
      });
    }

    const yearData = deptData[year];
    if (!yearData) {
      return res.status(404).json({
        success: false,
        message: "Year not found"
      });
    }

    const sectionData = yearData[section];
    if (!sectionData) {
      return res.status(404).json({
        success: false,
        message: "Section not found"
      });
    }

    return res.json({
      success: true,
      data: sectionData
    });

  } catch (error) {
    console.error("Timetable Error:", error);
    res.status(500).json({
      success: false,
      message: "Server Error"
    });
  }
});

module.exports = router;
