# All MI Conditions for people who are Male OR had an office visit at some point in the data
{
  person_filter: {
    left: { icd9: '412' },
    right: {
      union: [
        { cpt: '99214' },
        { gender: 'Male' }
      ]
    }
  }
}

