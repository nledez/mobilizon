import Vue from 'vue';

declare module 'vue/types/vue' {
  interface Vue {
    $notifier: {
      success: (message: string) => void;
      error: (message: string) => void;
    };
  }
}

export class Notifier {
  private readonly vue: typeof Vue;

  constructor(vue: typeof Vue) {
    this.vue = vue;
  }

  success(message: string) {
    this.vue.prototype.$buefy.notification.open({
      message,
      duration: 5000,
      position: 'is-bottom-right',
      type: 'is-success',
      hasIcon: true,
    });
  }

  error(message: string) {
    this.vue.prototype.$buefy.notification.open({
      message,
      duration: 5000,
      position: 'is-bottom-right',
      type: 'is-danger',
      hasIcon: true,
    });
  }
}

// tslint:disable
export function NotifierPlugin(vue: typeof Vue, options?: any): void {
  vue.prototype.$notifier = new Notifier(vue);
}
