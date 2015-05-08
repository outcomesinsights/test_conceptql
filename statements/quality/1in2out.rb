#1 inpatient, or 2 outpatient diagnoses separated by 30 days, common pattern for claims data
{
let: [
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
          { recall: 'Heart Attack Visit'},
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
          { recall: 'Heart Attack Visit'},
          {
            complement: {
              place_of_service_code: 21
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
          left: { recall: 'Outpatient Heart Attack' },
          right: {
            time_window: [
              { recall: 'Outpatient Heart Attack' },
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
        { recall: 'Inpatient Heart Attack' },
        { recall: 'Earlier of Two Outpatient Heart Attacks'}
      ]
    }
  }
]

}
