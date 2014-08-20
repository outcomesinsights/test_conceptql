# NQF 002 with SQL Output
measurement_period = {
  date_range: {
    start: '2000-01-01',
    end: '2099-12-31'
  }
}
initial_population = {
  during: {
    left: {
      time_window: [
        { person: true },
        { start: '+2y', end: '+17y' }
      ]
    },
    right: measurement_period
  }
}

initial_population_2 = {
  during: {
    left: measurement_period,
    right: {
      time_window: [
        { person: true },
        { start: '+2y', end: '+18y' }
      ]
    }
  }
}

ambulatory_cpts = {
  cpt: %w(99201 99202 99203 99204 99205 99212 99213 99214 99215 99218 99219 99220 99281 99282 99283 99284 99285 99381 99382 99383 99384 99385 99386 99387 99391 99392 99393 99394 99395 99396 99397)
}

pharyngitis_diagnoses = {
  union: [
    { icd9: %w(034.0 462) },
    { icd10: %w(J02.0 J02.9) }
  ]
}

ambulatory_encounters = {
  during: {
    left: {
      visit_occurrence: ambulatory_cpts
    },
    right: initial_population
  }
}

pharyngitis_medication = {
  intersect: [
    { rxnorm: %w(1013662 1013665 1043022 1043027 1043030 105152 105170 105171 108449 1113012 1148107 1244762 1249602 1302650 1302659 1302664 1302669 1302674 1373014 141962 141963 142118 1423080 1483787 197449 197450 197451 197452 197453 197454 197511 197512 197516 197517 197518 197595 197596) },
    { drug_type_concept: %w(38000175 38000176 38000177 38000179) }
  ]
}

ambulatory_encounters_with_pharyngitis = {
  intersect: [
    ambulatory_encounters,
    {
      visit_occurrence: pharyngitis_diagnoses
    }
  ]
}

ambulatory_encounter_with_meds = {
  during: {
    left: ambulatory_encounters_with_pharyngitis,
    right: {
      time_window: [
        pharyngitis_medication,
        { start: '-3d', end: 'start' }
      ]
    }
  }
}

meds_before_ambulatory_encounter = {
  during: {
    left: ambulatory_encounters,
    right: {
      time_window: [
        pharyngitis_medication,
        { start: '0', end: '30d' }
      ]
    }
  }
}

{
  except: {
    left: ambulatory_encounter_with_meds,
    right: meds_before_ambulatory_encounter
  }
}
