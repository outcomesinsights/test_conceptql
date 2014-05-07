# All Conditions that are MI unless they are primary diagnoses
{
  except: {
    left: { icd9: '412' },
    right: { condition_type: :inpatient_header }
  }
}

