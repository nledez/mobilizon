<template>
  <div class="root">
    <h1 class="title">
      <span v-if="isUpdate">{{ identity.displayName() }}</span>
      <span v-else>{{ $t('I create an identity') }}</span>
    </h1>

    <picture-upload v-model="avatarFile" class="picture-upload"></picture-upload>

    <b-field :label="$t('Display name')">
      <b-input aria-required="true" required v-model="identity.name" @input="autoUpdateUsername($event)"/>
    </b-field>

    <b-field :label="$t('Username')">
      <b-field>
        <b-input aria-required="true" required v-model="identity.preferredUsername" :disabled="isUpdate"/>

        <p class="control">
          <span class="button is-static">@{{ getInstanceHost() }}</span>
        </p>
      </b-field>
    </b-field>

    <b-field :label="$t('Description')">
      <b-input type="textarea" aria-required="false" v-model="identity.summary"/>
    </b-field>

    <b-notification
          type="is-danger"
          has-icon
          aria-close-label="Close notification"
          role="alert"
          :key="error"
          v-for="error in errors"
    >
    {{ error }}
  </b-notification>

    <b-field class="submit">
      <div class="control">
        <button type="button" class="button is-primary" @click="submit()">
          {{ $t('Save') }}
        </button>
      </div>
    </b-field>

    <div class="delete-identity" v-if="isUpdate">
      <span @click="openDeleteIdentityConfirmation()">
        {{ $t('Delete this identity') }}
      </span>
    </div>
  </div>
</template>

<style scoped type="scss">
  h1 {
    display: flex;
    justify-content: center;
  }

  .picture-upload {
    margin: 30px 0;
  }

  .submit,
  .delete-identity {
    display: flex;
    justify-content: center;
  }

  .submit {
    margin: 30px 0;
  }

  .delete-identity {
    text-decoration: underline;
    cursor: pointer;
    margin-top: 15px;
  }
</style>

<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import {
  CREATE_PERSON,
  CURRENT_ACTOR_CLIENT,
  DELETE_PERSON,
  FETCH_PERSON,
  IDENTITIES,
  UPDATE_PERSON,
} from '@/graphql/actor';
import { IPerson, Person } from '@/types/actor';
import PictureUpload from '@/components/PictureUpload.vue';
import { MOBILIZON_INSTANCE_HOST } from '@/api/_entrypoint';
import { Dialog } from 'buefy/dist/components/dialog';
import { RouteName } from '@/router';
import { buildFileFromIPicture, buildFileVariable, readFileAsync } from '@/utils/image';
import { changeIdentity } from '@/utils/auth';

@Component({
  components: {
    PictureUpload,
    Dialog,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class EditIdentity extends Vue {
  @Prop({ type: Boolean }) isUpdate!: boolean;

  errors: string[] = [];

  identityName!: string | undefined;
  avatarFile: File | null = null;
  identity = new Person();

  private oldDisplayName: string | null = null;
  private currentActor: IPerson | null = null;

  @Watch('isUpdate')
  async isUpdateChanged () {
    this.resetFields();
  }

  @Watch('$route.params.identityName', { immediate: true })
  async onIdentityParamChanged (val: string) {
    // Only used when we update the identity
    if (this.isUpdate !== true) return;

    await this.redirectIfNoIdentitySelected(val);

    this.resetFields();
    this.identityName = val;

    if (this.identityName) {
      this.identity = await this.getIdentity();

      this.avatarFile = await buildFileFromIPicture(this.identity.avatar);
    }
  }

  submit() {
    if (this.isUpdate) return this.updateIdentity();

    return this.createIdentity();
  }

  autoUpdateUsername(newDisplayName: string | null) {
    const oldUsername = this.convertToUsername(this.oldDisplayName);

    if (this.identity.preferredUsername === oldUsername) {
      this.identity.preferredUsername = this.convertToUsername(newDisplayName);
    }

    this.oldDisplayName = newDisplayName;
  }

  /**
   * Delete an identity
   */
  async deleteIdentity() {
    try {
      await this.$apollo.mutate({
        mutation: DELETE_PERSON,
        variables: {
          id: this.identity.id,
        },
        update: (store) => {
          const data = store.readQuery<{ identities: IPerson[] }>({ query: IDENTITIES });

          if (data) {
            data.identities = data.identities.filter(i => i.id !== this.identity.id);

            store.writeQuery({ query: IDENTITIES, data });
          }
        },
      });

      this.$notifier.success(
        this.$t('Identity {displayName} deleted', { displayName: this.identity.displayName() }) as string,
      );
      /**
       * If we just deleted the current identity, we need to change it to the next one
       */
      const data = this.$apollo.provider.defaultClient.readQuery<{ identities: IPerson[] }>({ query: IDENTITIES });
      if (data) {
        await this.maybeUpdateCurrentActorCache(data.identities[0]);
      }

      await this.redirectIfNoIdentitySelected();
    } catch (err) {
      this.handleError(err);
    }
  }

  async updateIdentity() {
    try {
      const variables = await this.buildVariables();

      await this.$apollo.mutate({
        mutation: UPDATE_PERSON,
        variables,
        update: (store, { data: { updatePerson } }) => {
          const data = store.readQuery<{ identities: IPerson[] }>({ query: IDENTITIES });

          if (data) {
            const index = data.identities.findIndex(i => i.id === this.identity.id);

            this.$set(data.identities, index, updatePerson);
            this.maybeUpdateCurrentActorCache(updatePerson);

            store.writeQuery({ query: IDENTITIES, data });
          }
        },
      });

      this.$notifier.success(
        this.$t('Identity {displayName} updated', { displayName: this.identity.displayName() }) as string,
      );
    } catch (err) {
      this.handleError(err);
    }
  }

  async createIdentity() {
    try {
      const variables = await this.buildVariables();

      await this.$apollo.mutate({
        mutation: CREATE_PERSON,
        variables,
        update: (store, { data: { createPerson } }) => {
          const data = store.readQuery<{ identities: IPerson[] }>({ query: IDENTITIES });

          if (data) {
            data.identities.push(createPerson);

            store.writeQuery({ query: IDENTITIES, data });
          }
        },
      });

      this.$notifier.success(
              this.$t('Identity {displayName} created', { displayName: this.identity.displayName() }) as string,
      );

      await this.$router.push({ name: RouteName.UPDATE_IDENTITY, params: { identityName: this.identity.preferredUsername } });
    } catch (err) {
      this.handleError(err);
    }
  }

  getInstanceHost() {
    return MOBILIZON_INSTANCE_HOST;
  }

  openDeleteIdentityConfirmation() {
    this.$buefy.dialog.prompt({
      type: 'is-danger',
      title: this.$t('Delete your identity') as string,
      message: `${this.$t('This will delete / anonymize all content (events, comments, messages, participations…) created from this identity.')}
            <br /><br />
            ${this.$t('If this identity is the only administrator of some groups, you need to delete them before being able to delete this identity.')}
            ${this.$t('Otherwise this identity will just be removed from the group administrators.')}
            <br /><br />
            ${this.$t('To confirm, type your identity username "{preferredUsername}"', { preferredUsername: this.identity.preferredUsername })}`,
      confirmText: this.$t(
        'Delete {preferredUsername}',
        { preferredUsername: this.identity.preferredUsername },
      ) as string,
      inputAttrs: {
        placeholder: this.identity.preferredUsername,
        pattern: this.identity.preferredUsername,
      },

      onConfirm: () => this.deleteIdentity(),
    });
  }

  private async getIdentity() {
    const result = await this.$apollo.query({
      query: FETCH_PERSON,
      variables: {
        username: this.identityName,
      },
    });

    return new Person(result.data.fetchPerson);
  }

  private handleError(err: any) {
    console.error(err);

    if (err.graphQLErrors !== undefined) {
      err.graphQLErrors.forEach(({ message }) => {
        this.$notifier.error(message);
      });
    }
  }

  private convertToUsername(value: string | null) {
    if (!value) return '';

    // https://stackoverflow.com/a/37511463
    return value.toLocaleLowerCase()
                .normalize('NFD')
                .replace(/[\u0300-\u036f]/g, '')
                .replace(/ /g, '_')
                .replace(/[^a-z0-9._]/g, '')
    ;
  }

  private async buildVariables() {
    const avatarObj = buildFileVariable(this.avatarFile, 'avatar', `${this.identity.preferredUsername}'s avatar`);
    const res = Object.assign({}, this.identity, avatarObj);
    /**
     * If the avatar didn't change, no need to try reuploading it
     */
    if (this.identity.avatar) {
      const oldAvatarFile = await buildFileFromIPicture(this.identity.avatar) as File;
      const oldAvatarFileContent = await readFileAsync(oldAvatarFile);
      const newAvatarFileContent = await readFileAsync(this.avatarFile as File);
      if (oldAvatarFileContent === newAvatarFileContent) {
        res.avatar = null;
      }
    }
    return res;
  }

  private async redirectIfNoIdentitySelected (identityParam?: string) {
    if (!!identityParam) return;

    await this.loadLoggedPersonIfNeeded();

    if (!!this.currentActor) {
      await this.$router.push({ params: { identityName: this.currentActor.preferredUsername } });
    }
  }

  private async maybeUpdateCurrentActorCache(identity: IPerson) {
    if (this.currentActor) {
      if (this.currentActor.preferredUsername === this.identity.preferredUsername) {
        await changeIdentity(this.$apollo.provider.defaultClient, identity);
      }
      this.currentActor = identity;
    }
  }

  private async loadLoggedPersonIfNeeded (bypassCache = false) {
    if (this.currentActor) return;

    const result = await this.$apollo.query({
      query: CURRENT_ACTOR_CLIENT,
      fetchPolicy: bypassCache ? 'network-only' : undefined,
    });

    this.currentActor = result.data.currentActor;
  }

  private resetFields () {
    this.identityName = undefined;
    this.identity = new Person();
    this.oldDisplayName = null;
    this.avatarFile = null;
  }
}
</script>
