const options = { year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute: 'numeric' }

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
export const parseDate = (date: string) => new Date(date).toLocaleDateString('de-DE', options)
export const parseDateCalendar = (date: string) =>
  new Date(date).toLocaleDateString('de-DE', { year: 'numeric', month: 'long', day: 'numeric' })

export const parseDateCalendarShort = (date: string) =>
  new Date(date).toLocaleDateString('de-DE', { month: 'short', day: 'numeric' })
