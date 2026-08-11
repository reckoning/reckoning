<script setup lang="ts">
import {useCustomers} from "@/services/api/services/customers/customers"

const {data: customers, isPending, isError} = useCustomers()
</script>

<template>
  <div class="p-4">
    <h1 class="text-xl font-semibold">Customers</h1>

    <p v-if="isPending" data-testid="loading">Loading…</p>
    <p v-else-if="isError" data-testid="error">Could not load customers.</p>

    <ul v-else data-testid="customers">
      <li v-for="customer in customers" :key="customer.id">
        {{ customer.name }}
      </li>
    </ul>
  </div>
</template>
