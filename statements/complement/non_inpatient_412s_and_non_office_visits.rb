# Yields two streams: a stream of all Conditions where the conditions isn't an MI and Primary Diagnosis and a stream of all non-office visit Procedures
{
  complement: {
    union: [
      { icd9: '412' },
      { condition_type: :inpatient_header },
      { cpt: '99214' }
    ]
  }
}

