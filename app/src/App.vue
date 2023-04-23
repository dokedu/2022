<script setup lang="ts">
import gql from 'graphql-tag';
import { useMutation, useQuery } from "@urql/vue";
import { computed, ref } from 'vue';

const query = gql`query {
    tasks {
        edges {
            node {
                id
                name
                createdAt
            }
        }
    }
}`

const { fetching, error, data } = useQuery(
    {
        query
    }
)

const tasks = computed(() => {
    return data.value?.tasks?.edges?.map((edge: any) => edge.node) ?? []
})

const { executeMutation: createTask } = useMutation(
    gql`mutation ($name: String!) {
            createTask(input: { name: $name, description: "New task" }) {
                id
                name
            }
        }`,
)

// delete mutation
const { executeMutation: deleteTodo } = useMutation(
    gql`mutation ($id: ID!) {
            deleteTask(id: $id) {
                id
            }
        }`,
)

// update mutation
const { executeMutation: updateTodo } = useMutation(
    gql`mutation ($id: ID!, $name: String!) {
            updateTask(input: { id: $id, name: $name, description: "Updated task" }) {
                id
                name
            }
        }`,
)

const name = ref<string>('')

function addTask() {
    if (!name.value) return
    if (name.value.length < 3) return

    createTask({
        name: name.value
    })

    name.value = ''
}

function deleteTask(id: string) {
    deleteTodo({
        id
    })
}

function updateTask(task, event) {
    if (task.name === event.target.value) return

    updateTodo({ id: task.id, name: event.target.value })
}

</script>

<template>
    <div class="min-h-screen p-4">
        <form @submit.prevent="addTask" class="flex gap-2 mb-8">
            <input v-model="name" type="text" name="name" id="name" placeholder="Task name">
            <input type="submit" value="Add task" class="px-4 py-1 border border-black hover:bg-neutral-50">
        </form>

        <div v-if="fetching">
            Loading...
        </div>
        <div v-else-if="error">
            Oh no... {{ error }}
        </div>
        <div v-else class="flex flex-col gap-2">
            <div v-for="task in tasks" :key="task.id" class="flex gap-2">
                <input type="text" :value="task.name" class="border-none hover:bg-neutral-100 rounded-md"
                    @blur="updateTask(task, $event)">

                <button @click="deleteTask(task.id)"
                    class="py-2 px-3 hover:bg-red-100 bg-red-50 rounded-md text-red-800">Delete</button>
            </div>
        </div>
    </div>
</template>
