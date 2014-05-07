# All Conditions where the Condition isn't an MI as the Primary Diagnosis
{
  complement: {
    union: [
      { icd9: '412' },
      { condition_type: :inpatient_header }
    ]
  }
}

