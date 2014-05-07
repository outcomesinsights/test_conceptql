# Yields two streams: a stream of all Conditions where the conditions isn't an MI and Primary Diagnosis and a stream of all non-office visit Procedures (same as above)
{
  union: [
    {
      intersect: [
        { complement: { icd9: '412' } },
        { complement: { condition_type: :inpatient_header } }
      ]
    },
    { complement: { cpt: '99214' } }
  ]
}

