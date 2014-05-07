# All Conditions where the Condition isn't an MI as the Primary Diagnosis (same as above)
{
  intersect: [
    { complement: { icd9: '412' } },
    { complement: {  condition_type: :inpatient_header } }
  ]
}

