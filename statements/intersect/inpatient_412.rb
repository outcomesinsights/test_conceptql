# Yields a single stream of all Conditions where MI was Primary Diagnosis.
# This involves two Condition streams and so results are intersected
{
  intersect: [
    { icd9: '412' },
    { condition_type: :inpatient_header }
  ]
}

