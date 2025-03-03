# kaniko-standalone

This GitHub action enables Kaniko builds on github runner without the need to start an extra kaniko container.

The action relies on kaniko binaries extracted from the public container image, these binaries are run in a chroot environment that mimics a basic container.

The action takes four parameters:

```
  dockerfile:
    description: 'Path to the Dockerfile'
    required: true
  destination:
    description: 'Docker registry destination (image:tag)'
    required: true
  platform:
    description: 'Build platform (default: amd64, arm64, ppc64le, s390x)'
    required: false
    default: 'amd64'
  extra_args:
    description: 'Extra arguments to Kaniko'
    required: false
    default: ''
```

An example action looks like this:

```
      - name: 🏗️ Kaniko build
        uses: k8stooling/kaniko-standalone@v1
        with:
          dockerfile: ${{ github.workspace }}/Dockerfile
          destination: public.ecr.aws/myrepo/myimage:latest
          platform: amd64 
```


☠️☠️☠️☠️☠️☠️☠️☠️☠️

THE EXTRACTED BINARIES MUST BE RUN ONLY IN A CONTAINERIZED/CHROOT/EPHEMERAL ENVIRONMENT

KANIKO MAKES SERIOUS IRREVERSIBLE DAMAGE TO THE ROOT FILESYSTEM

YOU HAVE BEEN WARNED

☠️☠️☠️☠️☠️☠️☠️☠️☠️


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
