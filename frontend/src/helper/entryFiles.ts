export const decodeFileName = (string: string) => {
  return string.split('/')[string.split('/').length - 1].slice(22)
  // try {
  // const name = string.split('/')[string.split('/').length - 1].slice(22)
  // return window.atob(decodeURI(name))
  // } catch (error) {
  //   return '#' + string.split('/')[string.split('/').length - 1].slice(22)
  // }
}

export const encodeFileName = (string: string) => {
  // return window.btoa(window.encodeURI(string))
  return string
}
