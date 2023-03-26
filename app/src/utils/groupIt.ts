import { groupBy } from "./groupBy"

export const groupIt = (items: object | [], keys: string[], keyIndex = 0) => {
    let group: object

    if (Array.isArray(items)) {
        group = groupBy(items, keys[keyIndex])
    } else {
        group = items
    }

    let data = {}

    for (const item in group) {
        if (keys.length - 1 === keyIndex) {
            data[item] = group[item]
        } else {
            data[item] = groupIt(group[item], keys, keyIndex + 1)
        }

    }

    return data
}