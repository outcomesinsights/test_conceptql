# Passes three streams downstream: a stream of Conditions that are MI but not primary diagnosis, a stream of People that are Male but not White, and a stream of Procedures that are office visits (this stream is completely unaffected by the right hand stream)
{
  except: {
    left: {
      union: [
        { icd9: '412' },
        { gender: 'Male' },
        { cpt: '99214' }
      ]
    },
    right: {
      union: [
        { condition_type: :inpatient_header },
        { race: 'White' },
      ]
    }
  }
}

