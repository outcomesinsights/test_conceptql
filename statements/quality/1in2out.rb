#1 inpatient, or 2 outpatient diagnoses separated by 30 days, common pattern for claims data
[
  {
    define: [
      'Heart Attack Visit',
      { visit_occurrence: { icd9: '412' } }
    ]
  },

  {
    define: [
      'Inpatient Heart Attack',
      {
        intersect: [
          { from: 'Heart Attack Visit'},
          { place_of_service_code: 21 }
        ]
      }
    ]
  },

  {
    define: [
      'Outpatient Heart Attack',
      {
        intersect: [
          { from: 'Heart Attack Visit'},
          {
            complement: {
              place_of_service_code: 23
            }
          }
        ]
      }
    ]
  },

  {
    define: [
      'Earlier of Two Outpatient Heart Attacks',
      {
        before: {
          left: { from: 'Outpatient Heart Attack' },
          right: {
            time_window: [
              { from: 'Outpatient Heart Attack' },
              { start: '-30d', end: '0' }
            ]
          }
        }
      }
    ]
  },

  {
    first: {
      union: [
        { from: 'Inpatient Heart Attack' },
        { from: 'Earlier of Two Outpatient Heart Attacks'}
      ]
    }
  }
]
