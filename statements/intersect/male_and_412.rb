# Yields two streams: a stream of all MI Conditions and a stream of all Male patients.
#  This is essentially the same behavior as Union in this case
{
  intersect: [
    { icd9: '412' },
    { gender: 'Male' }
  ]
}

