<template>
  <div class="my-4 mt-12 max-w-[420px] rounded-lg border-2 border-blue-200 bg-blue-100 p-4 text-sm text-blue-900">
    <div>Wir arbeiten ununterbrochen daran, euch hier bald die folgenden Funktionen anbieten zu können:</div>

    <div class="my-2 flex flex-col space-y-1 font-medium text-blue-900">
      <slot></slot>
    </div>
    <div>
      Bis dahin bitten wir dich, dich zu gedulden. Wenn du Fragen hast, kannst du dich gerne an uns wenden:
      <a href="mailto:help@dokedu.org" class="font-medium">help@dokedu.org</a>.
    </div>
  </div>
</template>
