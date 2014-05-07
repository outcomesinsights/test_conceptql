# All Conditions that are MI unless they are primary diagnoses (same as above)
{
  intersect: [
    { icd9: '412' },
    { complement: { condition_type: :inpatient_header } }
  ]
}

