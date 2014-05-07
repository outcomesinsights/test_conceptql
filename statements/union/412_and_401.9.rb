# Two streams of the same type (condition_occurrence) joined into a single stream
{
  union: [
    { icd9: '412' },
    { icd9: '401.9' }
  ]
}

