# Two streams of the same type (condition_occurrence) joined into a single stream, then a different stream (visit_occurrence) flows concurrently
{
  union: [
    {union: [
      { icd9: '412' },
      { icd9: '401.9' }
    ]},
    { place_of_service_code: '21' }
  ]
}

