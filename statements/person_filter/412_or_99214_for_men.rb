# Yields two streams: a stream of all MI Conditions for people who are Male and a stream of all office visit Procedures for people who are Male
{
  person_filter: {
    left: {
      union: [
         { icd9: '412' },
         { cpt: '99214' }
      ]
    },
    right: { gender: 'Male' }
  }
}

