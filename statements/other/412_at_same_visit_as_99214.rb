# All Visits Where a Patient Had an MI During and Office Visit
{
  intersect: [
    {
      visit_occurrence: {
        icd9: '412'
      }
    },
    {
      visit_occurrence: {
        cpt: '99214'
      }
    }
  ]
}

