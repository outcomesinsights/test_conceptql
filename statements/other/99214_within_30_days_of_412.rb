# All Diagnoses of Hypertension (ICD-9 401.9) within 30 days of an MI
{
  during: {
    left: { cpt: '99214' },
    right: {
      time_window: [
        { icd9: '412' },
        { start: '-30d', end: '30d' }
      ]
    }
  }
}

