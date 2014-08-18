# OMOP HOI: Acute Kidney disease
#
#- ICD-9 of 584
#- AND
#  - ICD-9 procedure codes of 39.95 or 54.98 within 60 days after diagnosis
#- AND NOT
#  - A diagnostic code of chronic dialysis any time before initial diagnosis
#    - V45.1, V56.0, V56.31, V56.32, V56.8

{
  during: {
    left: {
      except: {
        left: { icd9: '584' },
        right: {
          after: {
            left: { icd9: '584' },
            right: { icd9: [ 'V45.1', 'V56.0', 'V56.31', 'V56.32', 'V56.8' ] }
          }
        }
      }
    },
    right: {
      time_window: [
         { icd9_procedure: [ '39.95', '54.98' ] },
         { start: '0', end: '60d' }
      ]
    }
  }
}

