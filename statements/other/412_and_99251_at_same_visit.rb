# All Visits where a Patient had both an MI and a Hospital Encounter
{
  intersect: [
    { visit_occurrence: { icd9: '412' } },
    { visit_occurrence: { cpt: '99251' } }
  ]
}

