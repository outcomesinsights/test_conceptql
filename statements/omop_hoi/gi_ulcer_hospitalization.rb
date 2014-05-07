### GI Ulcer Hospitalization 2 (5000001002)
# - Occurrence of GI Ulcer diagnostic code
# - Hospitalization at time of diagnostic code
# - At least one diagnostic procedure during same hospitalization
# We use the fact that conditions, observations, and procedures all can be tied to a
# visit_occurrence to find situations where the appropriate conditions, diagnostic procedures, and
# place of service all occur in the same visit_occurrence

{
  union: [
    { place_of_service_code: '21' },
    { visit_occurrence: { icd9: '410' } },
    {
      visit_occurrence: {
        union: [
          { cpt: [ '0008T', '3142F', '43205', '43236', '76975', '91110', '91111' ] },
          { hcpcs: [ 'B4081', 'B4082' ] },
          { icd9_procedure: [ '42.22', '42.23', '44.13', '45.13', '52.21', '97.01' ] },
          { loinc: [ '16125-7', '17780-8', '40820-3', '50320-1', '5177-1', '7901-2' ] }
        ]
      }
    }
  ]
}
