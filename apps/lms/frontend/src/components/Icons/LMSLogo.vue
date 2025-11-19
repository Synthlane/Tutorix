<template>
	<img
		:src="logoUrl"
		alt="Synthlane Logo"
		class="lms-logo"
		style="max-width: 100%; height: auto;"
	/>
</template>

<script setup>
import { computed } from 'vue'

// Use computed to construct URL at runtime to avoid Vite trying to resolve it during build
const logoUrl = computed(() => {
	const base = import.meta.env.BASE_URL || '/assets/lms/frontend/'
	return `${base}logo.svg`
})
</script>

<style>
.lms-logo {
	/* Logo SVG now uses #fd7e14 directly - no filter needed */
	transition: opacity 0.3s ease;
}
</style>
