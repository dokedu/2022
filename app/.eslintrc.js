module.exports = {
  root: true,
  env: {
    browser: true,
    es2021: true,
    node: true,
  },
  extends: [
    'plugin:vue/vue3-recommended',
    'eslint:recommended',
    '@vue/typescript/recommended',
    '@vue/prettier',
    '@vue/prettier/@typescript-eslint',
    'plugin:cypress/recommended',
  ],
  parserOptions: {
    ecmaVersion: 2021,
  },
  plugins: ['cypress'],

  rules: {},
}
