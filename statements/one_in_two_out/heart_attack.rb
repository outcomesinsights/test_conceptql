#1 inpatient, or 2 outpatient diagnoses separated by 30 days, common pattern for claims data
{
  one_in_two_out: [
    { icd9: '412' },
    { gap: 30, blah: true }
  ]
}
