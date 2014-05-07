Sequel.migration do
  change do
    alter_table(:care_site, :ignore_index_errors=>true) do
      index [:location_id, :organization_id, :place_of_service_source_value], :name=>:care_site_location_id_organization_id_place_of_service_sour_key, :unique=>true
      index [:care_site_id], :name=>:carsit_carsitid
      index [:location_id], :name=>:carsit_locid
      index [:organization_id], :name=>:carsit_orgid
      index [:place_of_service_concept_id], :name=>:carsit_plaofserconid
      index [:location_id, :organization_id, :place_of_service_source_value, :care_site_id], :name=>:idx_care_site_org_sources
    end

    alter_table(:cohort, :ignore_index_errors=>true) do
      index [:cohort_concept_id], :name=>:coh_cohconid
      index [:cohort_id], :name=>:coh_cohid
      index [:subject_id], :name=>:coh_subid
    end

    alter_table(:location, :ignore_index_errors=>true) do
      index [:location_id], :name=>:loc_locid
      index [:zip, :county], :name=>:location_zip_county_key, :unique=>true
    end

    alter_table(:provider, :ignore_index_errors=>true) do
      index [:provider_source_value, :specialty_source_value, :provider_id, :care_site_id], :name=>:idx_provider_lkp
      index [:care_site_id], :name=>:pro_carsitid
      index [:provider_id], :name=>:pro_proid
      index [:specialty_concept_id], :name=>:pro_speconid
    end

    alter_table(:organization, :ignore_index_errors=>true) do
      index [:location_id], :name=>:org_locid
      index [:organization_id], :name=>:org_orgid
      index [:place_of_service_concept_id], :name=>:org_plaofserconid
    end

    alter_table(:person, :ignore_index_errors=>true) do
      index [:care_site_id], :name=>:per_carsitid
      index [:ethnicity_concept_id], :name=>:per_ethconid
      index [:gender_concept_id], :name=>:per_genconid
      index [:location_id], :name=>:per_locid
      index [:person_id], :name=>:per_perid
      index [:provider_id], :name=>:per_proid
      index [:race_concept_id], :name=>:per_racconid
    end

    alter_table(:condition_era, :ignore_index_errors=>true) do
      index [:condition_concept_id], :name=>:conera_conconid
      index [:condition_era_id], :name=>:conera_coneraid
      index [:condition_type_concept_id], :name=>:conera_contypconid
      index [:person_id], :name=>:conera_perid
    end

    alter_table(:condition_occurrence, :ignore_index_errors=>true) do
      index [:condition_concept_id], :name=>:cci
      index [:associated_provider_id], :name=>:conocc_assproid
      index [:condition_concept_id], :name=>:conocc_conconid
      index [:condition_occurrence_id], :name=>:conocc_conoccid
      index [:condition_source_value], :name=>:conocc_consouval
      index [:condition_type_concept_id], :name=>:conocc_contypconid
      index [:person_id], :name=>:conocc_perid
      index [:visit_occurrence_id], :name=>:conocc_visoccid
      index [:visit_occurrence_id], :name=>:voi
    end

    alter_table(:death, :ignore_index_errors=>true) do
      index [:cause_of_death_concept_id], :name=>:dea_cauofdeaconid
      index [:death_type_concept_id], :name=>:dea_deatypconid
      index [:person_id], :name=>:dea_perid
    end

    alter_table(:drug_era, :ignore_index_errors=>true) do
      index [:drug_concept_id], :name=>:druera_druconid
      index [:drug_era_id], :name=>:druera_drueraid
      index [:drug_type_concept_id], :name=>:druera_drutypconid
      index [:person_id], :name=>:druera_perid
    end

    alter_table(:drug_exposure, :ignore_index_errors=>true) do
      index [:drug_concept_id], :name=>:druexp_druconid
      index [:drug_exposure_id], :name=>:druexp_druexpid
      index [:drug_type_concept_id], :name=>:druexp_drutypconid
      index [:person_id], :name=>:druexp_perid
      index [:prescribing_provider_id], :name=>:druexp_preproid
      index [:relevant_condition_concept_id], :name=>:druexp_relconconid
      index [:visit_occurrence_id], :name=>:druexp_visoccid
    end

    alter_table(:observation, :ignore_index_errors=>true) do
      index [:associated_provider_id], :name=>:obs_assproid
      index [:observation_concept_id], :name=>:obs_obsconid
      index [:observation_id], :name=>:obs_obsid
      index [:observation_type_concept_id], :name=>:obs_obstypconid
      index [:person_id], :name=>:obs_perid
      index [:relevant_condition_concept_id], :name=>:obs_relconconid
      index [:unit_concept_id], :name=>:obs_uniconid
      index [:value_as_concept_id], :name=>:obs_valasconid
      index [:visit_occurrence_id], :name=>:obs_visoccid
    end

    alter_table(:observation_period, :ignore_index_errors=>true) do
      index [:person_id, :observation_period_start_date, :observation_period_end_date], :name=>:idx_observation_period_lkp
      index [:observation_period_id], :name=>:obsper_obsperid
      index [:person_id], :name=>:obsper_perid
    end

    alter_table(:payer_plan_period, :ignore_index_errors=>true) do
      index [:person_id, :plan_source_value, :payer_plan_period_start_date, :payer_plan_period_end_date], :name=>:idx_payer_plan_period_lkp
      index [:payer_plan_period_id], :name=>:payplaper_payplaperid
      index [:person_id], :name=>:payplaper_perid
    end

    alter_table(:procedure_occurrence, :ignore_index_errors=>true) do
      index [:associated_provider_id], :name=>:proocc_assproid
      index [:person_id], :name=>:proocc_perid
      index [:procedure_concept_id], :name=>:proocc_proconid
      index [:procedure_occurrence_id], :name=>:proocc_prooccid
      index [:procedure_source_value], :name=>:proocc_prosouval
      index [:procedure_type_concept_id], :name=>:proocc_protypconid
      index [:relevant_condition_concept_id], :name=>:proocc_relconconid
      index [:visit_occurrence_id], :name=>:proocc_visoccid
    end

    alter_table(:visit_occurrence, :ignore_index_errors=>true) do
      index [:person_id, :visit_start_date, :place_of_service_concept_id], :name=>:visit_occurrence_person_id_visit_start_date_place_of_servic_key, :unique=>true
      index [:care_site_id], :name=>:visocc_carsitid
      index [:person_id], :name=>:visocc_perid
      index [:place_of_service_concept_id], :name=>:visocc_plaofserconid
      index [:visit_occurrence_id], :name=>:visocc_visoccid
    end

    alter_table(:drug_cost, :ignore_index_errors=>true) do
      index [:drug_cost_id], :name=>:drucos_drucosid
      index [:drug_exposure_id], :name=>:drucos_druexpid
      index [:payer_plan_period_id], :name=>:drucos_payplaperid
    end

    alter_table(:procedure_cost, :ignore_index_errors=>true) do
      index [:disease_class_concept_id], :name=>:procos_disclaconid
      index [:payer_plan_period_id], :name=>:procos_payplaperid
      index [:procedure_cost_id], :name=>:procos_procosid
      index [:procedure_occurrence_id], :name=>:procos_prooccid
      index [:revenue_code_concept_id], :name=>:procos_revcodconid
    end
  end
end
