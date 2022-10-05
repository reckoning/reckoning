<template>
  <div class="py-6">
    <div class="mx-auto px-4 sm:px-6 md:px-8">
      <h1 class="text-2xl text-gray-900">Timers</h1>
      <div>
        <header
          class="flex items-center justify-between border-b border-gray-200 py-4 px-6"
        >
          <h1 class="text-lg text-gray-900">
            <time :datetime="String(year)">{{ year }}</time>
          </h1>
          <div class="flex items-center">
            <div
              class="flex items-center rounded-md shadow-sm md:items-stretch"
            >
              <router-link
                :to="{
                  name: 'timers-test-year',
                  params: { year: previousYear },
                }"
                class="flex items-center justify-center rounded-l-md border border-r-0 border-gray-300 bg-white py-2 pl-3 pr-4 text-gray-400 hover:text-gray-500 focus:relative md:w-9 md:px-2 md:hover:bg-gray-50"
              >
                <span class="sr-only">Previous month</span>
                <ChevronLeftIcon class="h-5 w-5" aria-hidden="true" />
              </router-link>
              <router-link
                :to="{ name: 'timers' }"
                class="hidden items-center justify-center border-t border-b border-gray-300 bg-white px-3.5 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:text-gray-900 focus:relative md:flex"
              >
                Today
              </router-link>
              <span class="relative -mx-px h-5 w-px bg-gray-300 md:hidden" />

              <router-link
                :to="{ name: 'timers-test-year', params: { year: nextYear } }"
                class="flex items-center justify-center rounded-r-md border border-l-0 border-gray-300 bg-white py-2 pl-4 pr-3 text-gray-400 hover:text-gray-500 focus:relative md:w-9 md:px-2 md:hover:bg-gray-50"
              >
                <span class="sr-only">Next month</span>
                <ChevronRightIcon class="h-5 w-5" aria-hidden="true" />
              </router-link>
            </div>
            <div class="hidden md:ml-4 md:flex md:items-center">
              <Menu as="div" class="relative">
                <MenuButton
                  type="button"
                  class="flex items-center rounded-md border border-gray-300 bg-white py-2 pl-3 pr-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50"
                >
                  Year view
                  <ChevronDownIcon
                    class="ml-2 h-5 w-5 text-gray-400"
                    aria-hidden="true"
                  />
                </MenuButton>

                <transition
                  enter-active-class="transition ease-out duration-100"
                  enter-from-class="transform opacity-0 scale-95"
                  enter-to-class="transform opacity-100 scale-100"
                  leave-active-class="transition ease-in duration-75"
                  leave-from-class="transform opacity-100 scale-100"
                  leave-to-class="transform opacity-0 scale-95"
                >
                  <MenuItems
                    class="absolute right-0 z-10 mt-3 w-36 origin-top-right overflow-hidden rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                  >
                    <div class="py-1">
                      <MenuItem v-slot="{ active }">
                        <a
                          href="#"
                          :class="[
                            active
                              ? 'bg-gray-100 text-gray-900'
                              : 'text-gray-700',
                            'block px-4 py-2 text-sm',
                          ]"
                          >Day view</a
                        >
                      </MenuItem>
                      <MenuItem v-slot="{ active }">
                        <a
                          href="#"
                          :class="[
                            active
                              ? 'bg-gray-100 text-gray-900'
                              : 'text-gray-700',
                            'block px-4 py-2 text-sm',
                          ]"
                          >Week view</a
                        >
                      </MenuItem>
                      <MenuItem v-slot="{ active }">
                        <a
                          href="#"
                          :class="[
                            active
                              ? 'bg-gray-100 text-gray-900'
                              : 'text-gray-700',
                            'block px-4 py-2 text-sm',
                          ]"
                          >Month view</a
                        >
                      </MenuItem>
                      <MenuItem v-slot="{ active }">
                        <a
                          href="#"
                          :class="[
                            active
                              ? 'bg-gray-100 text-gray-900'
                              : 'text-gray-700',
                            'block px-4 py-2 text-sm',
                          ]"
                          >Year view</a
                        >
                      </MenuItem>
                    </div>
                  </MenuItems>
                </transition>
              </Menu>
              <div class="ml-6 h-6 w-px bg-gray-300" />
              <button
                type="button"
                class="ml-6 rounded-md border border-transparent bg-brand-primary py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              >
                Add Timer
              </button>
            </div>
            <Menu as="div" class="relative ml-6 md:hidden">
              <MenuButton
                class="-mx-2 flex items-center rounded-full border border-transparent p-2 text-gray-400 hover:text-gray-500"
              >
                <span class="sr-only">Open menu</span>
                <EllipsisHorizontalIcon class="h-5 w-5" aria-hidden="true" />
              </MenuButton>

              <transition
                enter-active-class="transition ease-out duration-100"
                enter-from-class="transform opacity-0 scale-95"
                enter-to-class="transform opacity-100 scale-100"
                leave-active-class="transition ease-in duration-75"
                leave-from-class="transform opacity-100 scale-100"
                leave-to-class="transform opacity-0 scale-95"
              >
                <MenuItems
                  class="absolute right-0 z-10 mt-3 w-36 origin-top-right divide-y divide-gray-100 overflow-hidden rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                >
                  <div class="py-1">
                    <MenuItem v-slot="{ active }">
                      <a
                        href="#"
                        :class="[
                          active
                            ? 'bg-gray-100 text-gray-900'
                            : 'text-gray-700',
                          'block px-4 py-2 text-sm',
                        ]"
                        >Create event</a
                      >
                    </MenuItem>
                  </div>
                  <div class="py-1">
                    <MenuItem>
                      <router-link
                        :to="{ name: 'timers', params: { year: 2022 } }"
                        href="#"
                        class="text-gray-700 block px-4 py-2 text-sm"
                      >
                        Go to today
                      </router-link>
                    </MenuItem>
                  </div>
                  <div class="py-1">
                    <MenuItem v-slot="{ active }">
                      <a
                        href="#"
                        :class="[
                          active
                            ? 'bg-gray-100 text-gray-900'
                            : 'text-gray-700',
                          'block px-4 py-2 text-sm',
                        ]"
                      >
                        Day view
                      </a>
                    </MenuItem>
                    <MenuItem v-slot="{ active }">
                      <a
                        href="#"
                        :class="[
                          active
                            ? 'bg-gray-100 text-gray-900'
                            : 'text-gray-700',
                          'block px-4 py-2 text-sm',
                        ]"
                      >
                        Week view
                      </a>
                    </MenuItem>
                    <MenuItem v-slot="{ active }">
                      <a
                        href="#"
                        :class="[
                          active
                            ? 'bg-gray-100 text-gray-900'
                            : 'text-gray-700',
                          'block px-4 py-2 text-sm',
                        ]"
                      >
                        Month view
                      </a>
                    </MenuItem>
                    <MenuItem v-slot="{ active }">
                      <a
                        href="#"
                        :class="[
                          active
                            ? 'bg-gray-100 text-gray-900'
                            : 'text-gray-700',
                          'block px-4 py-2 text-sm',
                        ]"
                      >
                        Year view
                      </a>
                    </MenuItem>
                  </div>
                </MenuItems>
              </transition>
            </Menu>
          </div>
        </header>
        <div class="bg-white">
          <div
            :key="year"
            class="mx-auto grid max-w-3xl grid-cols-1 gap-x-8 gap-y-16 px-4 py-16 sm:grid-cols-2 sm:px-6 xl:max-w-none xl:grid-cols-3 xl:px-8 2xl:grid-cols-4"
          >
            <section
              v-for="month in months"
              :key="month.name"
              class="text-center"
            >
              <h2 class="font-semibold text-gray-900">{{ month.name }}</h2>
              <div
                class="mt-6 grid grid-cols-7 text-xs leading-6 text-gray-500"
              >
                <div>M</div>
                <div>T</div>
                <div>W</div>
                <div>T</div>
                <div>F</div>
                <div>S</div>
                <div>S</div>
              </div>
              <div
                class="isolate mt-2 grid grid-cols-7 gap-px rounded-lg bg-gray-200 text-sm shadow ring-1 ring-gray-200"
              >
                <button
                  v-for="(day, dayIdx) in month.days"
                  :key="day.date"
                  type="button"
                  :class="[
                    day.isCurrentMonth
                      ? 'bg-white text-gray-900'
                      : 'bg-gray-50 text-gray-400',
                    dayIdx === 0 && 'rounded-tl-lg',
                    dayIdx === 6 && 'rounded-tr-lg',
                    dayIdx === month.days.length - 7 && 'rounded-bl-lg',
                    dayIdx === month.days.length - 1 && 'rounded-br-lg',
                    'py-1.5 hover:bg-gray-100 focus:z-10',
                  ]"
                >
                  <time
                    :datetime="day.date"
                    :class="[
                      day.isToday &&
                        'bg-brand-primary font-semibold text-white',
                      'mx-auto flex h-7 w-7 items-center justify-center rounded-full',
                    ]"
                    >{{ format(new Date(day.date), "d") }}</time
                  >
                </button>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { useRoute } from "vue-router";
import {
  ChevronDownIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  EllipsisHorizontalIcon,
} from "@heroicons/vue/20/solid";
import { Menu, MenuButton, MenuItem, MenuItems } from "@headlessui/vue";
import {
  eachWeekOfInterval,
  eachDayOfInterval,
  lastDayOfWeek,
  addWeeks,
  endOfWeek,
  startOfWeek,
  isToday,
  format,
} from "date-fns";

const route = useRoute();

const year = computed((): number => {
  if (route.params.year) {
    return parseInt(route.params.year as string, 10);
  }

  return parseInt(format(new Date(), "yyyy"), 10);
});
const nextYear = computed(() => year.value + 1);
const previousYear = computed(() => year.value - 1);

const weekStartsOn = 1; // Monday
const monthIndexes = Array.from({ length: 12 }).map((_, index) => index);
const months = computed(() =>
  monthIndexes.map((index) => {
    const startOfMonth = new Date(year.value, index, 1);
    const startDay = startOfWeek(startOfMonth, { weekStartsOn });

    const weeksOfMonth = eachWeekOfInterval(
      {
        start: startDay,
        end: endOfWeek(addWeeks(startDay, 5), { weekStartsOn }),
      },
      { weekStartsOn }
    );

    const daysOfMonth = weeksOfMonth
      .map((day) =>
        eachDayOfInterval({
          start: day,
          end: lastDayOfWeek(day, { weekStartsOn }),
        })
      )
      .flat();

    const days = daysOfMonth.map((date) => ({
      date: format(date, "yyyy-MM-dd"),
      isCurrentMonth: date.getMonth() === index,
      isToday: isToday(date) && date.getMonth() === index,
    }));

    return {
      name: format(startOfMonth, "MMMM"),
      days,
    };
  })
);
</script>
