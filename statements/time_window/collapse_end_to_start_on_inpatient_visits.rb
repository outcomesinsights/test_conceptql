# Collapse all hospital visits' date ranges down to just the date of admission by leaving start_date unaffected and setting end_date to start_date
{
  time_window: [
    { place_of_service_code: '21' },
    { start: '', end: 'start' }
  ]
}

