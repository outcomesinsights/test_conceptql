# Defines a set of variables and assembles them into a statement

heart_attack = {
  define: [
    'heart attack',
    { icd9: %w(412) }
  ]
}

office_visits = {
  define: [
    'office visits',
    { cpt: %w(99211 99212 99213 99214 99215) }
  ]
}

{
let: [
  heart_attack,
  office_visits,
  {
    during: {
      left: { recall: 'heart attack' },
      right: { recall: 'office visits' }
    }
  }
]

}
