# All MIs that occurred after a male patient's 50th birthday
{
  after: {
    left: { icd9: '412' },
    right: {
      time_window: [
        { gender: 'Male' },
        {
          start: '50y',
          end: '50y'
        }
      ]
    }
  }
}

