# Yields two streams: a stream of all Conditions where MI was Primary Diagnosis and a stream of all White, Male patients.
{
  intersect: [
    { icd9: '412' },
    { condition_type: :inpatient_header },
    { gender: 'Male' },
    { race: 'White' }
  ]
}

