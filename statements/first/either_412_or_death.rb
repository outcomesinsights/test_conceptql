# First occurrence of either MI or Death for each patient
{
  first: {
    union: [
      { icd9: '412' },
      { death: true }
    ]
  }
}

