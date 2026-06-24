"use client";

import * as React from "react";
import { Check, Menu, Plus, Settings } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  RadioGroup,
  RadioGroupItem,
} from "@/components/ui/radio-group";
import { Separator } from "@/components/ui/separator";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { Switch } from "@/components/ui/switch";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { Toggle } from "@/components/ui/toggle";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";

const nav = [
  ["Overview", "overview"],
  ["Theme", "theme"],
  ["Buttons", "buttons"],
  ["Forms", "forms"],
  ["Overlays", "overlays"],
  ["Data Display", "data-display"],
  ["CLI", "cli"],
];

const baselineComponents = [
  "button",
  "button-group",
  "badge",
  "card",
  "input",
  "textarea",
  "label",
  "field",
  "checkbox",
  "radio-group",
  "select",
  "native-select",
  "dialog",
  "dropdown-menu",
  "table",
  "separator",
  "tabs",
  "toggle",
  "toggle-group",
  "switch",
  "sheet",
  "tooltip",
];

const themeTokens = [
  ["Background", "bg-background", "text-foreground"],
  ["Card", "bg-card", "text-card-foreground"],
  ["Primary", "bg-primary", "text-primary-foreground"],
  ["Secondary", "bg-secondary", "text-secondary-foreground"],
  ["Muted", "bg-muted", "text-muted-foreground"],
  ["Accent", "bg-accent", "text-accent-foreground"],
  ["Destructive", "bg-destructive", "text-destructive-foreground"],
  ["Border", "border-border", "text-foreground"],
];

function anchor(id: string) {
  return `#${id}`;
}

function Section({
  id,
  title,
  description,
  children,
}: {
  id: string;
  title: string;
  description: string;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className="scroll-mt-20 space-y-4 py-8">
      <div className="space-y-2">
        <h2 className="text-2xl font-semibold tracking-tight">{title}</h2>
        <p className="max-w-2xl text-sm text-muted-foreground">
          {description}
        </p>
      </div>
      {children}
    </section>
  );
}

function CodeBlock({ children }: { children: string }) {
  return (
    <pre className="overflow-x-auto rounded-md border bg-muted p-4 text-xs text-muted-foreground">
      <code>{children}</code>
    </pre>
  );
}

function NavList({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <nav className="grid gap-1">
      {nav.map(([label, id]) => (
        <a
          key={id}
          href={anchor(id)}
          onClick={onNavigate}
          className="rounded-md px-3 py-2 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        >
          {label}
        </a>
      ))}
    </nav>
  );
}

export function DesignSystem() {
  return (
    <TooltipProvider>
      <div className="min-h-screen bg-background text-foreground">
        <header className="sticky top-0 z-30 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/70">
          <div className="mx-auto flex h-14 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
            <div className="flex items-center gap-3">
              <Sheet>
                <SheetTrigger asChild>
                  <Button
                    variant="outline"
                    size="icon"
                    className="lg:hidden"
                    aria-label="Open navigation"
                  >
                    <Menu className="h-4 w-4" />
                  </Button>
                </SheetTrigger>
                <SheetContent side="left" className="w-72">
                  <SheetHeader>
                    <SheetTitle>Design System</SheetTitle>
                  </SheetHeader>
                  <div className="mt-6">
                    <NavList />
                  </div>
                </SheetContent>
              </Sheet>
              <span className="text-sm font-semibold">Design System</span>
              <Badge variant="secondary">shadcn</Badge>
            </div>
            <Button asChild variant="ghost" size="sm">
              <a href="https://ui.shadcn.com/docs" target="_blank" rel="noreferrer">
                Docs
              </a>
            </Button>
          </div>
        </header>

        <div className="mx-auto grid max-w-7xl grid-cols-1 lg:grid-cols-[16rem_1fr]">
          <aside className="hidden border-r lg:block">
            <div className="sticky top-14 max-h-[calc(100vh-3.5rem)] overflow-y-auto p-4">
              <NavList />
            </div>
          </aside>

          <main className="min-w-0 px-4 py-8 sm:px-6 lg:px-10">
            <section id="overview" className="scroll-mt-20 space-y-6 pb-8">
              <div className="max-w-3xl space-y-3">
                <Badge>__ROUTE_PATH__</Badge>
                <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">
                  shadcn-backed design system
                </h1>
                <p className="text-muted-foreground">
                  This page documents the shadcn components, semantic theme
                  tokens, and CLI workflow for this app. The source of truth is
                  <code className="mx-1 rounded bg-muted px-1 py-0.5 text-xs">
                    components.json
                  </code>
                  plus the installed files under
                  <code className="mx-1 rounded bg-muted px-1 py-0.5 text-xs">
                    components/ui
                  </code>
                  .
                </p>
              </div>

              <div className="grid gap-4 md:grid-cols-3">
                <Card>
                  <CardHeader>
                    <CardTitle>Source of truth</CardTitle>
                    <CardDescription>
                      Use shadcn config, aliases, and components.
                    </CardDescription>
                  </CardHeader>
                </Card>
                <Card>
                  <CardHeader>
                    <CardTitle>Preset-aware</CardTitle>
                    <CardDescription>
                      Apply presets with the shadcn CLI, not custom token files.
                    </CardDescription>
                  </CardHeader>
                </Card>
                <Card>
                  <CardHeader>
                    <CardTitle>Extend intentionally</CardTitle>
                    <CardDescription>
                      Add missing primitives with <code>shadcn add</code>.
                    </CardDescription>
                  </CardHeader>
                </Card>
              </div>
            </section>

            <Section
              id="theme"
              title="Theme"
              description="Use shadcn semantic tokens so preset changes flow through the app without rewriting component markup."
            >
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                {themeTokens.map(([label, bg, fg]) => (
                  <div key={label} className="rounded-lg border bg-card p-4">
                    <div className={`mb-3 h-16 rounded-md border ${bg}`} />
                    <div className="text-sm font-medium">{label}</div>
                    <div className="mt-1 text-xs text-muted-foreground">
                      <code>{bg}</code>
                      <br />
                      <code>{fg}</code>
                    </div>
                  </div>
                ))}
              </div>
              <CodeBlock>{`// Prefer semantic utilities.
<div className="rounded-lg border bg-card text-card-foreground" />
<Button variant="default">Primary action</Button>`}</CodeBlock>
            </Section>

            <Section
              id="buttons"
              title="Buttons"
              description="Use the installed shadcn Button variants. Do not create parallel names like primary or danger unless the local Button source intentionally defines them."
            >
              <Card>
                <CardContent className="flex flex-wrap gap-3 pt-6">
                  <Button>Default</Button>
                  <Button variant="secondary">Secondary</Button>
                  <Button variant="outline">Outline</Button>
                  <Button variant="ghost">Ghost</Button>
                  <Button variant="destructive">Destructive</Button>
                  <Button variant="link">Link</Button>
                  <Button size="icon" aria-label="Add">
                    <Plus className="h-4 w-4" />
                  </Button>
                  <Toggle aria-label="Toggle settings">
                    <Settings className="h-4 w-4" />
                  </Toggle>
                </CardContent>
              </Card>
              <CodeBlock>{`import { Button } from "@/components/ui/button";

<Button>Default</Button>
<Button variant="outline">Outline</Button>
<Button variant="destructive">Delete</Button>
<Button size="icon" aria-label="Add">
  <Plus className="h-4 w-4" />
</Button>`}</CodeBlock>
            </Section>

            <Section
              id="forms"
              title="Forms"
              description="Compose shadcn form controls with Label and semantic spacing. Use Field/native-select when those installed components better match the form structure."
            >
              <Card>
                <CardContent className="grid gap-6 pt-6 lg:grid-cols-2">
                  <div className="space-y-2">
                    <Label htmlFor="project-name">Project name</Label>
                    <Input id="project-name" placeholder="Acme dashboard" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="status">Status</Label>
                    <Select>
                      <SelectTrigger id="status">
                        <SelectValue placeholder="Choose a status" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="draft">Draft</SelectItem>
                        <SelectItem value="active">Active</SelectItem>
                        <SelectItem value="archived">Archived</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2 lg:col-span-2">
                    <Label htmlFor="notes">Notes</Label>
                    <Textarea id="notes" placeholder="Add implementation notes" />
                  </div>
                  <div className="flex items-center gap-2">
                    <Checkbox id="notify" />
                    <Label htmlFor="notify">Send a notification</Label>
                  </div>
                  <RadioGroup defaultValue="weekly" className="flex gap-4">
                    <div className="flex items-center gap-2">
                      <RadioGroupItem id="weekly" value="weekly" />
                      <Label htmlFor="weekly">Weekly</Label>
                    </div>
                    <div className="flex items-center gap-2">
                      <RadioGroupItem id="monthly" value="monthly" />
                      <Label htmlFor="monthly">Monthly</Label>
                    </div>
                  </RadioGroup>
                </CardContent>
              </Card>
            </Section>

            <Section
              id="overlays"
              title="Overlays and Menus"
              description="Use Dialog, Sheet, DropdownMenu, and Tooltip for layered UI. These components preserve expected focus and keyboard behavior."
            >
              <Card>
                <CardContent className="flex flex-wrap gap-3 pt-6">
                  <Dialog>
                    <DialogTrigger asChild>
                      <Button variant="outline">Open dialog</Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Archive project?</DialogTitle>
                        <DialogDescription>
                          This can be undone later from project settings.
                        </DialogDescription>
                      </DialogHeader>
                      <DialogFooter>
                        <Button variant="outline">Cancel</Button>
                        <Button>Continue</Button>
                      </DialogFooter>
                    </DialogContent>
                  </Dialog>

                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="outline">Open menu</Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="start">
                      <DropdownMenuLabel>Actions</DropdownMenuLabel>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem>Edit</DropdownMenuItem>
                      <DropdownMenuItem>Duplicate</DropdownMenuItem>
                      <DropdownMenuItem>Archive</DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>

                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button variant="ghost" size="icon" aria-label="Status">
                        <Check className="h-4 w-4" />
                      </Button>
                    </TooltipTrigger>
                    <TooltipContent>Ready</TooltipContent>
                  </Tooltip>

                  <div className="flex items-center gap-2 rounded-md border px-3 py-2">
                    <Switch id="public" />
                    <Label htmlFor="public">Public</Label>
                  </div>
                </CardContent>
              </Card>
            </Section>

            <Section
              id="data-display"
              title="Data Display"
              description="Use Card, Badge, Tabs, Separator, and Table for dense app UI. Keep layout utilities local; keep component styling in shadcn components."
            >
              <div className="grid gap-4 lg:grid-cols-[1fr_18rem]">
                <Card>
                  <CardHeader>
                    <CardTitle>Projects</CardTitle>
                    <CardDescription>Example table using shadcn primitives.</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Name</TableHead>
                          <TableHead>Status</TableHead>
                          <TableHead className="text-right">Tasks</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        <TableRow>
                          <TableCell>Atlas</TableCell>
                          <TableCell>
                            <Badge>Active</Badge>
                          </TableCell>
                          <TableCell className="text-right">24</TableCell>
                        </TableRow>
                        <TableRow>
                          <TableCell>Beacon</TableCell>
                          <TableCell>
                            <Badge variant="secondary">Draft</Badge>
                          </TableCell>
                          <TableCell className="text-right">8</TableCell>
                        </TableRow>
                      </TableBody>
                    </Table>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>Tabs</CardTitle>
                    <CardDescription>Organize related views.</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Tabs defaultValue="overview">
                      <TabsList>
                        <TabsTrigger value="overview">Overview</TabsTrigger>
                        <TabsTrigger value="activity">Activity</TabsTrigger>
                      </TabsList>
                      <TabsContent value="overview" className="text-sm text-muted-foreground">
                        Summary metrics and current state.
                      </TabsContent>
                      <TabsContent value="activity" className="text-sm text-muted-foreground">
                        Recent events and changes.
                      </TabsContent>
                    </Tabs>
                    <Separator className="my-4" />
                    <p className="text-sm text-muted-foreground">
                      Cards should frame real content, not act as page-section
                      decoration.
                    </p>
                  </CardContent>
                </Card>
              </div>
            </Section>

            <Section
              id="cli"
              title="CLI Workflow"
              description="Use shadcn commands to inspect, install, diff, and apply presets. This keeps component source and documentation aligned."
            >
              <div className="grid gap-4 lg:grid-cols-2">
                <Card>
                  <CardHeader>
                    <CardTitle>Baseline components</CardTitle>
                    <CardDescription>
                      These are installed by the design-system skill.
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="flex flex-wrap gap-2">
                    {baselineComponents.map((component) => (
                      <Badge key={component} variant="secondary">
                        {component}
                      </Badge>
                    ))}
                  </CardContent>
                </Card>
                <CodeBlock>{`npx shadcn@latest info --json
npx shadcn@latest preset resolve --json
npx shadcn@latest preset decode <code> --json
npx shadcn@latest apply <code> --yes
npx shadcn@latest add button --diff
npx shadcn@latest add dialog -y`}</CodeBlock>
              </div>
            </Section>
          </main>
        </div>
      </div>
    </TooltipProvider>
  );
}

export default DesignSystem;
