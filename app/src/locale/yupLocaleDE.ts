export function printValue(value: string, quoteStrings: boolean) {
  const result = printSimpleValue(value, quoteStrings)
  if (result !== null) return result

  return JSON.stringify(
    value,
    function (key, value) {
      const result = printSimpleValue(this[key], quoteStrings)
      if (result !== null) return result
      return value
    },
    2,
  )
}

function printNumber(val: number) {
  if (val !== +val) return 'NaN'
  const isNegativeZero = val === 0 && 1 / val < 0
  return isNegativeZero ? '-0' : '' + val
}
const symbolToString = typeof Symbol !== 'undefined' ? Symbol.prototype.toString : () => ''
const toString = Object.prototype.toString
const errorToString = Error.prototype.toString
const regExpToString = RegExp.prototype.toString
const SYMBOL_REGEXP = /^Symbol\((.*)\)(.*)$/

function printSimpleValue(val: any, quoteStrings = false) {
  if (val === null || val === true || val === false) return '' + val

  const typeOf = typeof val
  if (typeOf === 'number') return printNumber(val)
  if (typeOf === 'string') return quoteStrings ? `"${val}"` : val
  if (typeOf === 'function') return '[Function ' + (val.name || 'anonymous') + ']'
  if (typeOf === 'symbol') return symbolToString.call(val).replace(SYMBOL_REGEXP, 'Symbol($1)')

  const tag = toString.call(val).slice(8, -1)
  if (tag === 'Date') return isNaN(val.getTime()) ? '' + val : val.toISOString(val)
  if (tag === 'Error' || val instanceof Error) return '[' + errorToString.call(val) + ']'
  if (tag === 'RegExp') return regExpToString.call(val)

  return null
}

export const mixed = {
  default: '${path} ist ungültig',
  required: '${path} ist ein Pflichtfeld',
  oneOf: '${path} muss einem der folgenden Werte entsprechen: ${values}',
  notOneOf: '${path} darf keinem der folgenden Werte entsprechen: ${values}',
  notType: ({ path, type, value, originalValue }: any) => {
    const isCast = originalValue != null && originalValue !== value
    let msg =
      `${path} muss vom Typ \`${type}\` sein, ` +
      `aber der Wert war: \`${printValue(value, true)}\`` +
      (isCast ? ` (gecastet aus dem Wert \`${printValue(originalValue, true)}\`).` : '.')

    if (value === null) {
      msg += `\n Wenn "null" als leerer Wert gedacht ist, müssen Sie das Schema als \`.nullable()\` markieren.`
    }

    return msg
  },
}

export const string = {
  length: '${path} muss genau ${length} Zeichen lang sein',
  min: '${path} muss mindestens ${min} Zeichen lang sein',
  max: '${path} darf höchstens ${max} Zeichen lang sein',
  matches: '${path} muss wie folgt aussehen: "${regex}"',
  email: '${path} muss eine gültige E-Mail-Adresse enthalten',
  url: '${path} muss eine gültige URL sein',
  trim: '${path} darf keine Leerzeichen am Anfang oder Ende enthalten',
  lowercase: '${path} darf nur Kleinschreibung enthalten',
  uppercase: '${path} darf nur Großschreibung enthalten',
}

export const number = {
  min: '${path} muss größer oder gleich ${min} sein',
  max: '${path} muss kleiner oder gleich ${max} sein',
  lessThan: '${path} muss kleiner sein als ${less}',
  moreThan: '${path} muss größer sein als ${more}',
  notEqual: '${path} darf nicht gleich sein mit "${notEqual}"',
  positive: '${path} muss eine positive Zahl sein',
  negative: '${path} muss eine negative Zahl sein',
  integer: '${path} muss eine ganze Zahl sein',
}

export const date = {
  min: '${path} muss später sein als ${min}',
  max: '${path} muss früher sein als ${max}',
}

export const boolean = {}

export const object = {
  noUnknown: '${path}-Feld darf keine Schlüssel verwenden, die nicht im "Objekt-Shape" definiert wurden',
}

export const array = {
  min: '${path}-Feld muss mindesten ${min} Einträge haben',
  max: '${path}-Feld darf höchstens ${max} Einträge haben',
}

export default {
  mixed,
  string,
  number,
  date,
  object,
  array,
  boolean,
}
